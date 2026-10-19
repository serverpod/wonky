@Tags(['property'])
library;

import 'dart:math';

import 'package:test/test.dart';
import 'package:wonky_revlog/apply.dart';
import 'package:wonky_revlog/client.dart';
import 'package:wonky_revlog/codec.dart';
import 'package:wonky_revlog/rows.dart';

import '../support/test_schema.dart';

/// Chunking (RevLog spec 09 §2.7): big plans split into ops within the
/// change and byte limits, in plan order, one group; applying the chunks in
/// order equals applying the plan.
void main() {
  final codec = RevCodec(testSchema);

  for (final (seed, rows, cols) in [
    (1, 10, 3),
    (2, 2000, 4),
    (3, 6000, 5),
    (4, 24000, 5),
  ]) {
    test(
      'Given a plan of ${rows * cols + rows} changes (seed $seed) when chunked then every chunk is within the limits and the result is the same',
      () {
        final r = Random(seed);
        final rowIds = [for (var i = 0; i < rows; i++) newId()];
        final base = MapRowStore();
        applyChanges(testSchema, base, creation(rows: 0));
        final changes = <RowChange>[
          for (var i = 0; i < rows; i++) ...[
            RowChange.insert('row', rowIds[i], {
              'sheetId': sheetId,
              'sortKey': 'a${i.toString().padLeft(6, '0')}',
              'height': null,
            }),
            for (var c = 0; c < cols; c++)
              RowChange.insert('cell', cellId(sheetId, rowIds[i], c), {
                'sheetId': sheetId,
                'rowId': rowIds[i],
                'col': c,
                // Some long values to exercise the byte budget.
                'content': r.nextInt(50) == 0
                    ? 'x' * (2000 + r.nextInt(20000))
                    : 'v${r.nextInt(1000)}',
                'bold': r.nextBool() ? true : null,
                'at': null,
              }),
          ],
        ];
        final cs = ChangeSet(
          clientOpId: newId(),
          baseRevision: 3,
          changes: changes,
          label: 'Paste',
          summary: const {
            'kinds': ['values'],
          },
        );
        final chunks = RevChunker.split(cs, codec, newId);

        expect(chunks.expand((c) => c.changes).toList(), changes);
        if (chunks.length > 1) {
          expect(chunks.map((c) => c.groupId).toSet(), {cs.clientOpId});
          expect(
            [for (final c in chunks) c.groupIndex],
            [for (var i = 0; i < chunks.length; i++) i],
          );
          expect(chunks.last.groupLast, isTrue);
          expect(chunks.first.summary, cs.summary);
          expect(chunks.skip(1).every((c) => c.summary == null), isTrue);
          expect(
            chunks.map((c) => c.clientOpId).toSet(),
            hasLength(chunks.length),
          );
        }
        for (final c in chunks) {
          expect(
            c.changes.length,
            lessThanOrEqualTo(RevLimits.defaults.maxChangesPerOp),
          );
          final packed = RevCodec.pack(codec.encodeText(c.changes));
          final size = packed.gz?.length ?? packed.text!.length;
          expect(size, lessThanOrEqualTo(RevLimits.defaults.targetOpBytes));
        }

        final whole = base.copy();
        applyChanges(testSchema, whole, changes);
        final chunked = base.copy();
        for (final c in chunks) {
          final res = applyChangeSet(testSchema, chunked, c);
          expect(res.dropped, isEmpty, reason: 'rank order is kept');
        }
        expect(chunked.rows, whole.rows);
      },
      tags: rows > 5000 ? ['slow'] : null,
    );
  }
}
