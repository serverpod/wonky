import 'dart:math';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:wonky_write/features/editor/applier/delta_applier.dart';
import 'package:wonky_write/features/editor/controller/editor_pipeline.dart';

import '../support/delta_gen.dart';

void main() {
  var ids = 0;
  String newId() => 'n${ids++}';

  EditorPipeline pipelineFor(Delta delta, {List<List<Object>>? localChanges}) =>
      EditorPipeline(
        initialDelta: delta,
        newNodeId: newId,
        verifyInvariants: true,
        onTransaction: (changes, _) {
          if (changes.isNotEmpty) localChanges?.add(changes);
        },
      );

  group('Given a document with a caret', () {
    late EditorPipeline pipeline;
    late List<List<Object>> local;

    setUp(() {
      local = [];
      pipeline = pipelineFor(
        Delta()..insert('Hello world\nSecond\n'),
        localChanges: local,
      );
      pipeline.editor.execute([
        ChangeSelectionRequest(
          pipeline.mirror.selectionAt(6, 6),
          SelectionChangeType.placeCaret,
          SelectionReason.userInteraction,
        ),
      ]);
    });

    test(
      'when a remote insertion lands before the caret then the caret keeps its text position',
      () {
        pipeline.applier.apply(Delta()..insert('Oh, '));

        expect(pipeline.delta, Delta()..insert('Oh, Hello world\nSecond\n'));
        expect(pipeline.mirror.offsetsOf(pipeline.composer.selection!), (
          10,
          10,
        ));
      },
    );

    test(
      'when a remote insertion lands after the caret then the caret does not move',
      () {
        pipeline.applier.apply(
          Delta()
            ..retain(11)
            ..insert('!'),
        );

        expect(pipeline.mirror.offsetsOf(pipeline.composer.selection!), (6, 6));
      },
    );

    test(
      'when a remote change is applied then no local change is reported',
      () {
        pipeline.applier.apply(
          Delta()
            ..retain(12)
            ..insert('X'),
        );

        expect(local, isEmpty);
      },
    );

    test(
      'when a remote change splits the caret line then the caret follows its text',
      () {
        pipeline.applier.apply(
          Delta()
            ..retain(3)
            ..insert('\n'),
        );

        expect(pipeline.delta, Delta()..insert('Hel\nlo world\nSecond\n'));
        expect(pipeline.mirror.offsetsOf(pipeline.composer.selection!), (7, 7));
        expect(pipeline.document.nodeCount, 3);
      },
    );

    test(
      'when a remote change formats text then unchanged nodes keep their instances',
      () {
        final secondNode = pipeline.document.last;

        pipeline.applier.apply(Delta()..retain(5, {'bold': true}));

        expect(
          pipeline.delta,
          Delta()
            ..insert('Hello', {'bold': true})
            ..insert(' world\nSecond\n'),
        );
        expect(identical(pipeline.document.last, secondNode), isTrue);
      },
    );

    test(
      'when a remote change deletes the caret line then the caret moves to the nearest position',
      () {
        pipeline.applier.apply(Delta()..delete(12));

        expect(pipeline.delta, Delta()..insert('Second\n'));
        expect(pipeline.mirror.offsetsOf(pipeline.composer.selection!), (0, 0));
      },
    );
  });

  group('Given random documents and random changes', () {
    for (final seed in propertySeeds()) {
      test(
        'when applying them (seed $seed) then the document equals the composed Delta and the selection is transformed',
        () {
          final gen = DeltaGen(Random(seed));
          final changes = ChangeGen(gen);
          for (var run = 0; run < propertyRuns(20); run += 1) {
            var expected = gen.document(maxLines: 8);
            final pipeline = pipelineFor(expected);
            for (var step = 0; step < 8; step += 1) {
              // A random selection.
              final length = pipeline.mirror.length;
              final a = gen.random.nextInt(length);
              final b = gen.chance(0.5) ? a : gen.random.nextInt(length);
              pipeline.editor.execute([
                ChangeSelectionRequest(
                  pipeline.mirror.selectionAt(a, b),
                  SelectionChangeType.placeCaret,
                  SelectionReason.userInteraction,
                ),
              ]);
              final selectionBefore = pipeline.mirror.offsetsOf(
                pipeline.composer.selection!,
              )!;

              final change = changes.change(expected);
              if (change.isEmpty) continue;
              pipeline.applier.apply(change);
              expected = expected.compose(change);

              final reason = 'seed $seed run $run step $step change $change';
              expect(pipeline.delta, expected, reason: reason);
              expect(
                pipeline.mapper.deltaFromDocument(pipeline.document),
                expected,
                reason: reason,
              );

              final transformed = DeltaSelection(
                selectionBefore.$1,
                selectionBefore.$2,
              ).transform(change);
              final actual = pipeline.mirror.offsetsOf(
                pipeline.composer.selection!,
              )!;
              final maxOffset = pipeline.mirror.length - 1;
              expect(actual, (
                transformed.anchor.clamp(0, maxOffset),
                transformed.head.clamp(0, maxOffset),
              ), reason: reason);
            }
            pipeline.dispose();
          }
        },
      );
    }
  });
}
