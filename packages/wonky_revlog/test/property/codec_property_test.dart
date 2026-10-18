@Tags(['property'])
library;

import 'dart:math';

import 'package:test/test.dart';
import 'package:wonky_revlog/apply.dart';
import 'package:wonky_revlog/codec.dart';
import 'package:wonky_revlog/rows.dart';

import '../support/test_schema.dart';

void main() {
  final codec = RevCodec(testSchema);

  for (var seed = 0; seed < 20; seed++) {
    test(
      'Given random changes (seed $seed) when encoded and decoded then they round-trip',
      () {
        final r = Random(seed);
        final store = MapRowStore();
        applyChanges(testSchema, store, creation(rows: 4));
        final changes = <RowChange>[];
        for (var i = 0; i < 30; i++) {
          changes.addAll(randomEdit(r, _Reader(store), store));
        }
        changes.add(
          RowChange.insert('cell', cellId(sheetId, newId(), 9), {
            'sheetId': sheetId,
            'rowId': newId(),
            'col': 9,
            'content': 'ünïcødé ⟦R:x⟧',
            'bold': false,
            'at': DateTime.utc(2026, 10, 18, 1, 2, 3, 4),
          }),
        );
        final summary = {
          'kinds': ['values'],
          'sheets': [sheetId],
        };
        final text = codec.encodeText(changes, summary: summary);
        final back = codec.decodeText(text);
        expect(back.changes, changes);
        expect(back.summary, summary);
        expect(back.schemaHash, testSchema.hash);
        final packed = RevCodec.pack(text, threshold: 10);
        expect(RevCodec.unpack(gz: packed.gz), text);
      },
    );
  }

  test(
    'Given the applied form without before when decoded then updates have no before values',
    () {
      final change = RowChange.update(
        'sheet',
        sheetId,
        {'name': 'a'},
        {'name': 'b'},
      );
      final back = codec.decodeText(
        codec.encodeText([change], withBefore: false),
      );
      expect(back.changes.single.columnsBefore, isEmpty);
      expect(back.changes.single.columnsAfter, {'name': 'b'});
    },
  );

  test(
    'Given a payload with an unknown column when decoded leniently then it is skipped',
    () {
      final json = codec.encode([
        RowChange.update('sheet', sheetId, {'name': 'a'}, {'name': 'b'}),
      ]);
      (json['c']! as List)[0] = ['name', 'future'];
      final row = ((json['ch']! as List)[0] as List);
      row[3] = ['b', 7];
      row[4] = ['a', 6];
      expect(() => codec.decode(json), throwsA(isA<RevCodecException>()));
      final lenient = RevCodec(testSchema, lenient: true).decode(json);
      expect(lenient.changes.single.columnsAfter, {'name': 'b'});
    },
  );
}

final class _Reader implements CurrentRowReader {
  _Reader(this.store);
  final MapRowStore store;
  @override
  Map<String, Object?>? currentColumns(String table, String rowId) =>
      store.row(table, rowId);
}
