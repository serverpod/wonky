import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_revlog/schema.dart';
import 'package:wonky_revlog_flutter/src/store/rev_row_codec.dart';

/// The cache's binary row encoding (RevLog spec 17 As built 24).
void main() {
  const table = RevTable('t', [
    RevColumn('s', RevColumnType.string, nullable: true),
    RevColumn('u', RevColumnType.uuid, nullable: true),
    RevColumn('i', RevColumnType.int, nullable: true),
    RevColumn('d', RevColumnType.double, nullable: true),
    RevColumn('b', RevColumnType.bool, nullable: true),
    RevColumn('t', RevColumnType.dateTime, nullable: true),
    RevColumn('j', RevColumnType.json, nullable: true),
  ]);

  Map<String, Object?> roundTrip(Map<String, Object?> row) {
    final w = RevRowWriter()..row(table, row);
    final out = <String, Object?>{};
    RevRowReader(w.takeBytes()).row(table, out);
    return out;
  }

  group('Given rows of every value type', () {
    final cases = <String, Map<String, Object?>>{
      'ASCII and canonical uuids': {
        's': 'plain text',
        'u': '0190f0b0-0000-7000-8000-000000000001',
      },
      'uuid-like strings that are not canonical': {
        's': '0190F0B0-0000-7000-8000-000000000001',
        'u': '0190f0b0-0000-7000-8000-00000000000g',
      },
      'non-ASCII text': {'s': 'Grüße — 😀 ä€', 'j': '{"a":"ö"}'},
      'integers at the edges': {'i': -9007199254740991, 'd': -0.5},
      'large and small integers': {'i': 9007199254740991},
      'zero and one': {'i': 0, 'd': 1.0},
      'booleans and times': {
        'b': true,
        't': DateTime.utc(2026, 10, 18, 12, 30, 1, 250),
      },
      'false': {'b': false},
      'maps and lists': {
        'j': {
          'a': [1, 'x', null],
          'b': {'c': true},
        },
      },
      'a column the schema does not know': {'extra': 'kept', 's': 'x'},
      'empty strings': {'s': ''},
      'long strings': {'s': 'x' * 70000},
    };
    for (final MapEntry(key: name, value: row) in cases.entries) {
      test('when $name are encoded then they decode equal', () {
        expect(roundTrip(row), row);
      });
    }

    test('when nulls and the id are in the row then they are left out', () {
      expect(roundTrip({'id': 'x', 's': null, 'i': 3}), {'i': 3});
    });

    test('when random integers are encoded then they decode equal', () {
      final rnd = Random(5);
      for (var n = 0; n < 2000; n++) {
        final v = (rnd.nextDouble() * 2 - 1) * 9007199254740991;
        expect(roundTrip({'i': v.truncate()}), {'i': v.truncate()});
      }
    });
  });
}
