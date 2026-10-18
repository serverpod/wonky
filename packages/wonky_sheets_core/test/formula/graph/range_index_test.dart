import 'dart:math';

import 'package:test/test.dart';
import 'package:wonky_sheets_core/src/addressing/grid_geometry.dart';
import 'package:wonky_sheets_core/src/formula/graph/range_index.dart';

/// [RangeIndex] against a brute-force scan: keys are rectangles (resolved
/// as themselves), nodes are ints. Keys added after a query land in the
/// pending part (bucketed by row blocks) until the next rebuild.
void main() {
  Set<int> brute(Map<GridRect, Set<int>> keys, GridRect q) => {
    for (final e in keys.entries)
      if (e.key.intersects(q)) ...e.value,
  };

  Set<int> query(RangeIndex<GridRect, int> index, GridRect q) {
    final out = <int>[];
    index.intersect(q, out.add);
    // Every node once per key it is registered for.
    return out.toSet();
  }

  List<int> stabList(RangeIndex<GridRect, int> index, int r, int c) {
    final out = <int>[];
    index.stab(r, c, out.add);
    return out;
  }

  GridRect rect(Random rnd) {
    final top = rnd.nextInt(2000);
    final left = rnd.nextInt(30);
    final kind = rnd.nextInt(10);
    final height = switch (kind) {
      0 => 1 + rnd.nextInt(2000), // wide: many row blocks
      1 || 2 => 1 + rnd.nextInt(200),
      _ => 1 + rnd.nextInt(3), // a row or a few (fill-down formulas)
    };
    return GridRect(top, left, top + height - 1, left + rnd.nextInt(5));
  }

  for (final seed in [1, 7, 42]) {
    group('Given ranges added between queries (seed $seed)', () {
      test('when stabbing and intersecting then the nodes equal a brute-force '
          'scan, each node reported once', () {
        final rnd = Random(seed);
        final index = RangeIndex<GridRect, int>((k) => k);
        final keys = <GridRect, Set<int>>{};
        var node = 0;
        for (var round = 0; round < 300; round++) {
          for (var i = rnd.nextInt(40); i > 0; i--) {
            final k = rect(rnd);
            final n = node++;
            index.add(k, n);
            (keys[k] ??= {}).add(n);
          }
          if (rnd.nextInt(5) == 0 && keys.isNotEmpty) {
            final k = keys.keys.elementAt(rnd.nextInt(keys.length));
            final n = keys[k]!.first;
            index.remove(k, n);
            keys[k]!.remove(n);
            if (keys[k]!.isEmpty) keys.remove(k);
          }
          for (var i = 0; i < 20; i++) {
            final r = rnd.nextInt(2100), c = rnd.nextInt(36);
            final cell = GridRect(r, c, r, c);
            final got = stabList(index, r, c);
            expect(got.toSet(), brute(keys, cell));
            expect(got, hasLength(got.toSet().length));
          }
          final q = rect(rnd);
          expect(query(index, q), brute(keys, q));
        }
      });
    });
  }
}
