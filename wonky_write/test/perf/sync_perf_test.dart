/// Write sync client primitives on the `bench_100_pages` fixture (CQ-49,
/// Write 03 §7): what the client does per acknowledged op, per remote op
/// and per cursor update, the whole-document way and the windowed way.
/// Tagged `perf` like `write_perf_test.dart`:
///
/// ```sh
/// flutter test -t perf --run-skipped test/perf
/// ```
@Tags(['perf'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_core/wonky_core.dart' show UndoStep;
import 'package:wonky_write/features/document/write_undo.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import 'support/bench_document.dart';

/// Median µs of [count] runs of [body] (after a warm-up).
double _median(int count, void Function() body) {
  for (var i = 0; i < 5; i++) {
    body();
  }
  final samples = <int>[];
  for (var i = 0; i < count; i++) {
    final sw = Stopwatch()..start();
    body();
    samples.add(sw.elapsedMicroseconds);
  }
  samples.sort();
  return samples[samples.length ~/ 2].toDouble();
}

void main() {
  const normalizer = WonkyDeltaNormalizer();
  final doc = normalizer.normalize(BenchDocument.hundredPages().delta).document;
  final middle = DeltaUtils.documentLength(doc) ~/ 2;
  // A keystroke in the middle of the document.
  final typed = Delta()
    ..retain(middle)
    ..insert('x');

  test('Given the 100-page document when predicting the committed form of '
      'an acknowledged keystroke then the windowed normalization is faster '
      'and equal', () {
    final whole = _median(
      30,
      () => normalizer.normalizeChange(doc, typed).change,
    );
    final window = _median(30, () => normalizer.normalizedChange(doc, typed));
    // ignore: avoid_print
    print(
      '[perf] ack prediction: whole ${(whole / 1000).toStringAsFixed(2)} ms, '
      'windowed ${(window / 1000).toStringAsFixed(2)} ms',
    );

    expect(
      normalizer.normalizedChange(doc, typed),
      normalizer.normalizeChange(doc, typed).change,
    );
    expect(window, lessThan(whole));
  });

  test('Given the 100-page document when applying a remote keystroke to the '
      'server document then the windowed apply is faster and equal', () {
    final whole = _median(30, () => WonkyOt.apply(doc, typed));
    final window = _median(30, () => WonkyOt.applyToCanonical(doc, typed));
    // ignore: avoid_print
    print(
      '[perf] remote op on the server document: whole '
      '${(whole / 1000).toStringAsFixed(2)} ms, windowed '
      '${(window / 1000).toStringAsFixed(2)} ms',
    );

    expect(WonkyOt.applyToCanonical(doc, typed), WonkyOt.apply(doc, typed));
    expect(window, lessThan(whole));
  });

  test('Given 500 undo steps when a collaborator types elsewhere then the '
      'stacks are rebased without transforms', () {
    // 500 typing steps near the start (each undo entry deletes one char).
    final steps = [
      for (var i = 0; i < 500; i++)
        UndoStep(
          id: 'step-$i',
          label: 'Typing',
          entries: [
            WriteContentUndoEntry(
              change: Delta()
                ..retain(100 + i)
                ..delete(1),
            ),
          ],
        ),
    ];
    final remote = Delta()
      ..retain(middle)
      ..insert('r');
    final transforms = _median(20, () {
      var r = remote;
      for (final step in steps.reversed) {
        final u = (step.entries.single as WriteContentUndoEntry).change;
        WonkyOt.transform(r, u, aWinsTies: true);
        r = WonkyOt.transform(u, r, aWinsTies: false);
      }
    });
    final rebased = _median(
      20,
      () => rebaseWriteStacks(steps, const [], remote),
    );
    // ignore: avoid_print
    print(
      '[perf] rebase 500 undo steps over a remote op: transforms '
      '${(transforms / 1000).toStringAsFixed(2)} ms, disjoint fast path '
      '${(rebased / 1000).toStringAsFixed(2)} ms',
    );

    expect(rebased, lessThan(transforms));
  });

  test('Given a pending keystroke in the 100-page document when mapping a '
      'cursor to the server revision then no document walk is needed', () {
    final whole = _median(30, () {
      final inverse = WonkyOt.invert(typed, doc);
      WonkyOt.transformPosition(inverse, middle + 1, pushOnInsert: false);
    });
    final lengths = _median(30, () {
      final inverse = Delta()
        ..retain(middle)
        ..delete(1);
      WonkyOt.transformPosition(inverse, middle + 1, pushOnInsert: false);
    });
    // ignore: avoid_print
    print(
      '[perf] cursor mapping: invert against the document '
      '${(whole / 1000).toStringAsFixed(2)} ms, lengths only '
      '${(lengths / 1000).toStringAsFixed(3)} ms',
    );

    expect(lengths, lessThan(whole));
  });
}
