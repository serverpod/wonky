import 'dart:math';

import 'package:test/test.dart';
import 'package:uuid/uuid.dart';
import 'package:wonky_sync_models/ids.dart';
import 'package:wonky_sync_models/src/ids/uuid5.dart';

void main() {
  group('Given deterministic sheet ids', () {
    const sheet = '0190f6a0-0000-7000-8000-000000000001';
    const row = '0190f6a0-0000-7000-8000-000000000002';
    const col = '0190f6a0-0000-7000-8000-000000000003';

    test('when computing a cell id twice then both are equal', () {
      expect(
        SheetsIds.cellId(sheet, row, col),
        SheetsIds.cellId(sheet, row, col),
      );
    });

    test('when the input case differs then the cell id is the same', () {
      expect(
        SheetsIds.cellId(sheet.toUpperCase(), row, col.toUpperCase()),
        SheetsIds.cellId(sheet, row, col),
      );
    });

    test('when row and column are swapped then the cell ids differ', () {
      expect(
        SheetsIds.cellId(sheet, row, col),
        isNot(SheetsIds.cellId(sheet, col, row)),
      );
    });

    test('when computing a cell id then it is a version-5 UUID', () {
      final id = SheetsIds.cellId(sheet, row, col);
      expect(
        id,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    });

    test('when computing ids then they match the frozen vectors', () {
      // These ids are part of the synced data format and must never change.
      expect(
        SheetsIds.cellId(sheet, row, col),
        '7964be44-d005-5663-a857-a35ce06d99d9',
      );
      expect(
        SheetsIds.basicFilterId(sheet),
        'b245b271-6000-5903-be0a-fe6d5287499e',
      );
      expect(
        SheetsIds.scriptBuildId(sheet),
        '526a2236-95d2-5d06-8e56-04000974bb39',
      );
    });
  });

  group('Given the fast cell id hash', () {
    test('when hashing many random ids then each equals Uuid.v5 of the same '
        'name (the synced id format)', () {
      final ids = SeededIdGenerator(11);
      final rnd = Random(3);
      for (var i = 0; i < 2000; i++) {
        final sheet = ids.newId();
        final row = rnd.nextBool() ? ids.newId().toUpperCase() : ids.newId();
        final col = ids.newId();
        expect(
          SheetsIds.cellId(sheet, row, col),
          const Uuid().v5(
            SheetsIds.cellNamespace,
            'cell:${sheet.toLowerCase()}:${row.toLowerCase()}:'
            '${col.toLowerCase()}',
          ),
        );
      }
    });
  });

  group('Given the UUIDv5 hasher', () {
    final names = [
      '',
      'a',
      for (final n in [39, 40, 47, 48, 55, 56, 63, 64, 119, 120, 300]) 'x' * n,
      'Thème — größe',
      'emoji 😀 and ä€',
      'Ünïcödé ' * 20,
    ];
    for (final name in names) {
      test('when hashing a name of ${name.length} code units then it equals '
          'Uuid.v5', () {
        expect(
          Uuid5(SheetsIds.cellNamespace).of(name),
          const Uuid().v5(SheetsIds.cellNamespace, name),
        );
      });
    }

    test('when one hasher hashes a long and then a short name then the '
        'second id is not affected by the first', () {
      final h = Uuid5(SheetsIds.cellNamespace);
      h.of('y' * 500);
      expect(h.of('short'), const Uuid().v5(SheetsIds.cellNamespace, 'short'));
    });
  });

  group('Given the test id generators', () {
    test(
      'when seeding twice with the same seed then the sequences are equal',
      () {
        final a = SeededIdGenerator(7);
        final b = SeededIdGenerator(7);
        expect(
          List.generate(5, (_) => a.newId()),
          List.generate(5, (_) => b.newId()),
        );
      },
    );

    test('when generating sequential ids then they increase', () {
      final g = SequentialIdGenerator();
      expect(g.newId(), '00000000-0000-4000-8000-000000000001');
      expect(g.newId(), '00000000-0000-4000-8000-000000000002');
    });
  });
}
