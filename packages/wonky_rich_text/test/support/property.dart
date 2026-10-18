import 'dart:io';
import 'dart:math';

import 'package:test/test.dart';

/// Seeds for property tests: `WONKY_SEED` (an int or `random`) or a fixed list.
List<int> propertySeeds() {
  final env = Platform.environment['WONKY_SEED'];
  if (env == 'random') {
    final seed = Random().nextInt(0x7fffffff);
    print('WONKY_SEED=$seed');
    return [seed];
  }
  if (env != null && env.isNotEmpty) return [int.parse(env)];
  return const [1, 7, 42, 1234, 98765];
}

/// Iterations per seed: `WONKY_PROPERTY_RUNS` or [fallback].
int propertyRuns(int fallback) =>
    int.tryParse(Platform.environment['WONKY_PROPERTY_RUNS'] ?? '') ?? fallback;

/// Declares one property test per seed; [body] runs [runs] times with a
/// shared seeded [Random]. Failures report the seed and run for replay.
void propertyTest(
  String description,
  void Function(Random random, int run) body, {
  int runs = 200,
}) {
  for (final seed in propertySeeds()) {
    test('$description (WONKY_SEED=$seed)', () {
      final random = Random(seed);
      final n = propertyRuns(runs);
      for (var run = 0; run < n; run++) {
        try {
          body(random, run);
        } catch (e) {
          printOnFailure('Failed with WONKY_SEED=$seed at run $run');
          rethrow;
        }
      }
    }, tags: ['property']);
  }
}
