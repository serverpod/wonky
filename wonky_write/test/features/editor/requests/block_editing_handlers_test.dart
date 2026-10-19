import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_write/features/editor/applier/delta_applier.dart';

import '../support/editor_harness.dart';

Delta line(String text, [Map<String, dynamic>? attributes]) => Delta()
  ..insert(text)
  ..insert('\n', attributes);

Delta lines(List<Delta> parts) => parts.fold(Delta(), (d, p) => d.concat(p));

void main() {
  late EditorHarness h;
  tearDown(() => h.dispose());

  EditorHarness given(Delta delta, int caret) =>
      h = EditorHarness(delta)..select(caret);

  group('Enter (Write 04 §6.1)', () {
    test(
      'when pressing Enter at the end of a heading then a Normal paragraph follows',
      () {
        given(line('Title', {'header': 1}), 5).type('\n');
        expect(
          h.delta,
          lines([
            line('Title', {'header': 1}),
            line(''),
          ]),
        );
      },
    );

    test('when pressing Enter mid-heading then both parts stay headings', () {
      given(line('Title', {'header': 1}), 2).type('\n');
      expect(
        h.delta,
        lines([
          line('Ti', {'header': 1}),
          line('tle', {'header': 1}),
        ]),
      );
    });

    test(
      'when pressing Enter at the start of a heading then an empty Normal paragraph goes above',
      () {
        given(line('Title', {'header': 1}), 0).type('\n');
        expect(
          h.delta,
          lines([
            line(''),
            line('Title', {'header': 1}),
          ]),
        );
        expect(h.selection, const DeltaSelection.collapsed(1));
      },
    );

    test(
      'when pressing Enter in a quote then the quote continues, and on an empty line it ends',
      () {
        given(line('Q', {'blockquote': true}), 1).type('\n');
        expect(
          h.delta,
          lines([
            line('Q', {'blockquote': true}),
            line('', {'blockquote': true}),
          ]),
        );
        h.type('\n');
        expect(
          h.delta,
          lines([
            line('Q', {'blockquote': true}),
            line(''),
          ]),
        );
      },
    );

    test(
      'when pressing Enter on an empty indent-2 bullet then it outdents, twice more makes it Normal (AC-6.1)',
      () {
        given(
          lines([
            line('a', {'list': 'bullet'}),
            line('b', {'list': 'bullet', 'indent': 1}),
            line('', {'list': 'bullet', 'indent': 2}),
          ]),
          4,
        );
        h.type('\n');
        expect(h.delta.operations.last.attributes, {
          'list': 'bullet',
          'indent': 1,
        });
        h.type('\n');
        expect(h.delta.operations.last.attributes, {'list': 'bullet'});
        h.type('\n');
        expect(h.delta.operations.last.attributes, isNull);
        expect(h.changes, hasLength(3));
      },
    );

    test('when pressing Enter in a task then a new unchecked task follows', () {
      given(line('a', {'list': 'checked'}), 1).type('\n');
      expect(
        h.delta,
        lines([
          line('a', {'list': 'checked'}),
          line('', {'list': 'unchecked'}),
        ]),
      );
    });

    test('when pressing Enter in code then the indentation carries over', () {
      given(line('  if (x) {', {'code-block': 'dart'}), 10).type('\n');
      expect(h.plainText, '  if (x) {\n    \n');
    });

    test(
      'when pressing Enter three times at the end of code then the block is exited',
      () {
        given(line('a', {'code-block': ''}), 1).type('\n\n\n');
        expect(
          h.delta,
          lines([
            line('a', {'code-block': ''}),
            line(''),
          ]),
        );
      },
    );

    test(
      'when typing ```dart and Enter then the block is an empty dart code block (AC-7.2)',
      () {
        given(line(''), 0).type('```dart\n');
        expect(h.delta, line('', {'code-block': 'dart'}));
        expect(h.selection, const DeltaSelection.collapsed(0));
      },
    );

    test('when typing --- and Enter then a divider is inserted', () {
      given(line(''), 0).type('---\n');
      expect(h.delta.operations.first.data, isA<Map<Object?, Object?>>());
    });
  });

  group('Backspace (Write 04 §6.2)', () {
    test('at the start of a heading converts it to Normal', () {
      given(
        lines([
          line('a'),
          line('Title', {'header': 1}),
        ]),
        2,
      ).backspace();
      expect(h.delta, Delta()..insert('a\nTitle\n'));
    });

    test('at the start of an indented bullet outdents it', () {
      given(line('a', {'list': 'bullet', 'indent': 1}), 0).backspace();
      expect(h.delta, line('a', {'list': 'bullet'}));
    });

    test('at the start of a paragraph merges it into the previous one', () {
      given(Delta()..insert('a\nb\n'), 2).backspace();
      expect(h.delta, Delta()..insert('ab\n'));
      expect(h.selection, const DeltaSelection.collapsed(1));
    });

    test(
      'at the start of a paragraph after a table selects the table and deletes nothing (AC-6.2)',
      () {
        given(
          Delta()
            ..insert({
              'table': {
                'id': 't',
                'align': [null],
                'rows': [
                  ['a'],
                ],
              },
            })
            ..insert('\nb\n'),
          2,
        ).backspace();
        expect(h.plainText, '￼\nb\n');
        expect(h.selection, const DeltaSelection(0, 1));
      },
    );

    test('at the start of a code block converts every line to a paragraph', () {
      given(
        lines([
          line('a', {'code-block': ''}),
          line('b', {'code-block': ''}),
        ]),
        0,
      ).backspace();
      expect(h.delta, Delta()..insert('a\nb\n'));
    });

    test('next to a mention deletes the whole mention (AC-19.1)', () {
      given(
        Delta()
          ..insert('hi ')
          ..insert('@Anna Berg', {'mention': 'u', 'link': 'mailto:a@x.dev'})
          ..insert('\n'),
        13,
      ).backspace();
      expect(h.delta, Delta()..insert('hi \n'));
    });
  });

  group('Delete (Write 04 §6.3)', () {
    test('at the end of a paragraph before an image selects the image', () {
      given(
        Delta()
          ..insert('a\n')
          ..insert({
            'image': {'id': 'i', 'src': 'https://x.dev/i.png', 'alt': ''},
          })
          ..insert('\n'),
        1,
      ).delete();
      expect(h.selection, const DeltaSelection(2, 3));
    });

    test('at the end of a paragraph merges the next one', () {
      given(Delta()..insert('a\nb\n'), 1).delete();
      expect(h.delta, Delta()..insert('ab\n'));
    });
  });
}
