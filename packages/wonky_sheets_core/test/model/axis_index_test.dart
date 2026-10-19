import 'dart:math';

import 'package:test/test.dart';
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_sync_models/ids.dart';

/// Reference model of an axis: entries sorted by (sortKey, id).
final class _Reference {
  final Map<String, (String key, double? size, bool hidden)> entries = {};

  List<String> get ids {
    final list = entries.keys.toList()
      ..sort(
        (a, b) => FractionalIndex.compare(entries[a]!.$1, a, entries[b]!.$1, b),
      );
    return list;
  }
}

void main() {
  group('Given an axis index and a reference list', () {
    late AxisIndex axis;
    late _Reference reference;
    late Random random;
    var next = 0;

    String keyNear(List<String> ids) {
      if (ids.isEmpty) return FractionalIndex.first();
      final i = random.nextInt(ids.length + 1);
      return FractionalIndex.between(
        i == 0 ? null : reference.entries[ids[i - 1]]!.$1,
        i == ids.length ? null : reference.entries[ids[i]]!.$1,
      );
    }

    void check(String reason) {
      final ids = reference.ids;
      expect(axis.ids, ids, reason: reason);
      for (var i = 0; i < ids.length; i++) {
        expect(axis.indexOf(ids[i]), i, reason: '$reason: ${ids[i]}');
        expect(
          axis.explicitSizeAt(i),
          reference.entries[ids[i]]!.$2,
          reason: reason,
        );
        expect(
          axis.isUserHidden(i),
          reference.entries[ids[i]]!.$3,
          reason: reason,
        );
      }
      expect(axis.indexOf('missing'), -1, reason: reason);
      var offset = 0.0;
      for (var i = 0; i < ids.length; i++) {
        final e = reference.entries[ids[i]]!;
        offset += e.$3 ? 0 : (e.$2 ?? 21);
      }
      expect(axis.totalSize, offset, reason: reason);
    }

    setUp(() {
      axis = AxisIndex();
      reference = _Reference();
      random = Random(3);
      final keys = FractionalIndex.nBetween(null, null, 300);
      axis.load([for (var i = 0; i < 300; i++) ('a$i', keys[i], null, false)]);
      for (var i = 0; i < 300; i++) {
        reference.entries['a$i'] = (keys[i], null, false);
      }
    });

    test(
      'when small and large batches insert, move, resize and remove entries then order, '
      'indexes and sizes match',
      () {
        for (var step = 0; step < 150; step++) {
          // Batches of 1–3 entries (applied in place) and of 100 (merged).
          final size = step % 10 == 9 ? 100 : 1 + random.nextInt(3);
          for (var k = 0; k < size; k++) {
            final ids = reference.ids;
            switch (random.nextInt(4)) {
              case 0:
                final id = 'n${next++}';
                final key = keyNear(ids);
                axis.upsert(id, key);
                reference.entries[id] = (key, null, false);
              case 1 when ids.isNotEmpty:
                final id = ids[random.nextInt(ids.length)];
                axis.remove(id);
                reference.entries.remove(id);
              case 2 when ids.isNotEmpty:
                // Move: a new sort key.
                final id = ids[random.nextInt(ids.length)];
                final e = reference.entries[id]!;
                final key = keyNear(ids);
                axis.upsert(id, key, size: e.$2, hidden: e.$3);
                reference.entries[id] = (key, e.$2, e.$3);
              case 3 when ids.isNotEmpty:
                // Resize or hide in place.
                final id = ids[random.nextInt(ids.length)];
                final e = reference.entries[id]!;
                final px = random.nextBool() ? 40.0 : null;
                final hidden = random.nextInt(4) == 0;
                axis.upsert(id, e.$1, size: px, hidden: hidden);
                reference.entries[id] = (e.$1, px, hidden);
            }
          }
          // Read in between: some lookups before the next batch.
          final ids = reference.ids;
          if (ids.isNotEmpty) axis.indexOf(ids[random.nextInt(ids.length)]);
          if (step % 5 == 0) check('step $step');
        }
        check('end');
      },
    );

    test(
      'when one entry is inserted near the top then indexes above it need no rebuild '
      'and indexes below shift by one',
      () {
        final key = FractionalIndex.between(
          reference.entries['a9']!.$1,
          reference.entries['a10']!.$1,
        );
        final generation = axis.generation;

        axis.upsert('new', key);

        expect(axis.indexOf('a5'), 5);
        expect(axis.indexOf('new'), 10);
        expect(axis.indexOf('a10'), 11);
        expect(axis.indexOf('a299'), 300);
        expect(axis.generation, generation + 1);
      },
    );
  });
}
