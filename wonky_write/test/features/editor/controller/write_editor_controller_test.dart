import 'dart:math';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_write/features/editor/applier/delta_applier.dart';
import 'package:wonky_write/features/editor/controller/editor_types.dart';

import '../support/delta_gen.dart';
import '../support/editor_harness.dart';

void main() {
  group('Given an empty document', () {
    late EditorHarness h;
    setUp(() => h = EditorHarness(Delta()..insert('\n'))..select(0));
    tearDown(() => h.dispose());

    test(
      'when typing "Hello" then each keystroke is a typing change and undo removes it (AC-3.1)',
      () {
        h.type('Hello');

        expect(h.delta, Delta()..insert('Hello\n'));
        expect(
          h.changes.map((c) => c.kind),
          everyElement(LocalChangeKind.typing),
        );
        expect(h.changes.first.label, 'Typing');
        expect(
          h.changes.last.selectionAfter,
          const DeltaSelection.collapsed(5),
        );
        expect(h.changes[1].canCoalesce(h.changes[2]), isTrue);

        for (final change in h.changes.reversed.toList()) {
          h.undo(change);
        }
        expect(h.delta, Delta()..insert('\n'));
        expect(h.selection, const DeltaSelection.collapsed(0));
      },
    );

    test(
      'when typing "## Title" then the heading prefix is a separate autoformat step (AC-7.1)',
      () {
        h.type('## Title');

        expect(
          h.delta,
          Delta()
            ..insert('Title')
            ..insert('\n', {'header': 2}),
        );
        final autoformat = h.changes.singleWhere(
          (c) => c.label == 'Autoformat',
        );
        expect(autoformat.source, LocalChangeSource.reaction);

        // Undo everything typed after the autoformat, then the autoformat.
        final index = h.changes.indexOf(autoformat);
        for (final change in h.changes.sublist(index + 1).reversed.toList()) {
          h.undo(change);
        }
        h.undo(autoformat);
        expect(h.delta, Delta()..insert('## \n'));
      },
    );

    test(
      'when typing "- [ ] " then the paragraph becomes an unchecked task',
      () {
        h.type('- [ ] Buy milk');

        expect(
          h.delta,
          Delta()
            ..insert('Buy milk')
            ..insert('\n', {'list': 'unchecked'}),
        );
      },
    );

    test(
      'when typing a code fence with a language then the block is code with that language',
      () {
        h.type('```dart ');

        expect(h.delta, Delta()..insert('\n', {'code-block': 'dart'}));
      },
    );

    test('when typing "**bold** " then the text becomes bold', () {
      h.type('**bold** ');

      expect(
        h.delta,
        Delta()
          ..insert('bold', {'bold': true})
          ..insert(' \n'),
      );
    });

    test(
      'when typing quotes and dashes then smart typography applies (AC-8.1)',
      () {
        h.type('"Hi," she said -- ok...');

        expect(h.plainText, '“Hi,” she said — ok…\n');
      },
    );

    test(
      'with Markdown shortcuts off when typing "# " then nothing converts (AC-7.3)',
      () {
        h.controller.preferences = const WriteEditorPreferences(
          markdownShortcuts: false,
        );
        h.type('# x');

        expect(h.delta, Delta()..insert('# x\n'));
      },
    );
  });

  group('Given a document with a caret in the second line', () {
    late EditorHarness h;
    setUp(
      () => h = EditorHarness(Delta()..insert('First\nSecond\n'))..select(9),
    );
    tearDown(() => h.dispose());

    test(
      'when a remote insertion lands above then the caret keeps its text and no local change is made',
      () {
        h.controller.applyRemote(Delta()..insert('Remote '));

        expect(h.delta, Delta()..insert('Remote First\nSecond\n'));
        expect(h.selection, const DeltaSelection.collapsed(16));
        expect(h.changes, isEmpty);
      },
    );

    test(
      'when applying a local Delta then it is reported with its label and inverse',
      () {
        final change = h.controller.applyLocal(
          Delta()..retain(5, {'bold': true}),
          label: 'Bold',
        )!;

        expect(change.label, 'Bold');
        expect(change.inverse, Delta()..retain(5, {'bold': null}));
        expect(h.changes.single, same(change));
      },
    );

    test('when grouping two commands then one change is reported', () {
      h.controller.group('Paste', () {
        h.controller.applyLocal(Delta()..insert('a'), label: 'x');
        h.type('b');
      });

      expect(h.changes, hasLength(1));
      expect(h.changes.single.label, 'Paste');
      expect(
        (Delta()..insert('First\nSecond\n')).compose(h.changes.single.delta),
        h.delta,
      );
    });
  });

  group('Given Viewing mode', () {
    test(
      'when typing then nothing changes and no op is produced (AC-31.1)',
      () {
        final h = EditorHarness(
          Delta()..insert('Read only\n'),
          mode: EditorMode.viewing,
        )..select(4);
        h.type('xyz');
        h.backspace();

        expect(h.delta, Delta()..insert('Read only\n'));
        expect(h.changes, isEmpty);
        h.dispose();
      },
    );
  });

  group('Given Suggesting mode', () {
    test(
      'when replacing "old" by typing "new" then it becomes del + ins under one id (AC-32.1)',
      () {
        final h = EditorHarness(
          Delta()..insert('an old word\n'),
          mode: EditorMode.suggesting,
        )..select(3, 6);
        h.type('new');

        final ops = h.delta.operations;
        final del = ops.firstWhere((op) => op.data == 'old').attributes!;
        final ins = ops.firstWhere((op) => op.data == 'new').attributes!;
        expect(del.keys.single, ins.keys.single);
        expect((del.values.single as Map)['t'], 'del');
        expect((ins.values.single as Map)['t'], 'ins');
        expect(h.plainText, 'an oldnew word\n');
        expect(h.selection, const DeltaSelection.collapsed(9));
        h.dispose();
      },
    );

    test(
      'when pressing Backspace over existing text then it is marked deleted and the caret moves before it',
      () {
        final h = EditorHarness(
          Delta()..insert('abc\n'),
          mode: EditorMode.suggesting,
        )..select(3);
        h.backspace();

        expect(h.plainText, 'abc\n');
        expect(
          (h.delta.operations[1].attributes!.values.single as Map)['t'],
          'del',
        );
        expect(h.selection, const DeltaSelection.collapsed(2));
        h.dispose();
      },
    );

    for (final seed in propertySeeds()) {
      test('when making random changes (seed $seed) then the windowed '
          'rewrite equals the rewrite against the whole document (W-04)', () {
        final gen = DeltaGen(Random(seed));
        final changes = ChangeGen(gen);
        for (var run = 0; run < propertyRuns(10); run += 1) {
          // `verifyInvariants` (the harness) asserts the equality.
          final h = EditorHarness(
            gen.document(maxLines: 8),
            mode: EditorMode.suggesting,
          );
          for (var step = 0; step < 6; step += 1) {
            final change = changes.change(h.delta);
            if (change.isEmpty) continue;
            h.controller.applyLocal(change, label: 'Edit');
            h.advance(const Duration(seconds: 1));
          }
          final length = h.controller.length;
          h.select(gen.random.nextInt(length));
          h.type('ab');
          h.backspace();
          h.dispose();
        }
      });
    }

    test(
      'when deleting my own suggested insertion then it is really deleted',
      () {
        final h = EditorHarness(
          Delta()..insert('ab\n'),
          mode: EditorMode.suggesting,
        )..select(2);
        h.type('xy');
        h.backspace();
        h.backspace();

        expect(h.delta, Delta()..insert('ab\n'));
        h.dispose();
      },
    );
  });
}
