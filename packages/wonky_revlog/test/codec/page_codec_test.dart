import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:wonky_revlog/apply.dart';
import 'package:wonky_revlog/codec.dart';
import 'package:wonky_revlog/schema.dart';

import '../support/page_rows.dart';
import '../support/test_schema.dart';

const _docId = '0190f0b0-0000-7000-8000-0000000000aa';

void main() {
  group('Given a store of the test schema', () {
    late List<(String, Map<String, Object?>)> rows;
    setUp(() {
      final store = MapRowStore();
      applyChanges(testSchema, store, creation(rows: 3));
      rows = [
        for (final MapEntry(key: t, value: byId) in store.rows.entries)
          for (final row in byId.values) (t, row),
      ];
    });

    test('when its rows are encoded as a page and decoded then they '
        'round-trip without their null columns', () {
      final body = RevPageCodec.encode(testSchema, rows);

      final back = RevPageCodec.decode(testSchema, body);

      expect(flat(back), flat(decodedForm(testSchema, rows)));
    });

    test('when encoded as a version-1 body then it decodes with every '
        'column', () {
      final body = RevPageCodec.encodeLegacy(testSchema, rows);

      final back = RevPageCodec.decode(testSchema, body);

      expect(RevPageCodec.versionOf(body), RevPageCodec.legacyVersion);
      expect(flat(back), flat(rows));
    });
  });

  group('Given rows of every column type', () {
    final doc = (
      'doc',
      <String, Object?>{
        'id': _docId,
        'title': 'Doc',
        'mode': 'b',
        'zoom': null,
        'flag': true,
      },
    );
    final items = randomItems(Random(1), 300, docId: _docId);
    final rows = [doc, ...items];

    test('when encoded and decoded then values, nulls and defaults '
        'round-trip', () {
      final body = RevPageCodec.encode(pageSchema, rows);

      final back = RevPageCodec.decode(pageSchema, body);

      expect(RevPageCodec.versionOf(body), RevPageCodec.version);
      expect(flat(back), flat(decodedForm(pageSchema, rows)));
    });

    test('when a column with a non-null default is null then the decoded '
        'row says null explicitly', () {
      final back = RevPageCodec.decode(
        pageSchema,
        RevPageCodec.encode(pageSchema, [doc]),
      );

      expect(back.single.$2, containsPair('zoom', null));
      expect(back.single.$2.containsKey('zoom'), isTrue);
    });

    test('when encoded without compression then it decodes the same', () {
      final plain = RevPageCodec.encode(pageSchema, rows, compress: false);
      final packed = RevPageCodec.encode(pageSchema, rows);

      expect(
        flat(RevPageCodec.decode(pageSchema, plain)),
        flat(RevPageCodec.decode(pageSchema, packed)),
      );
      expect(packed.length, lessThan(plain.length));
    });

    test('when decoded in steps then every step adds rows or a column and '
        'the result equals the one-shot decode', () {
      final body = RevPageCodec.encode(pageSchema, rows);
      final out = <(String, Map<String, Object?>)>[];

      final steps = RevPageCodec.decodeSteps(
        pageSchema,
        body,
        out,
        rowsPerStep: 50,
      ).length;

      expect(steps, greaterThan(300 ~/ 50));
      expect(flat(out), flat(RevPageCodec.decode(pageSchema, body)));
    });
  });

  group('Given columnar input in wire forms', () {
    test('when UUIDs are bytes or objects, times are strings or '
        'milliseconds and enums are Enums then they decode to in-memory '
        'values', () {
      final id = randomUuid(Random(2));
      final owner = randomUuid(Random(3));
      final b = RevPageBuilder(pageSchema)
        ..addTable(
          'item',
          [_bytes(id)],
          {
            'docId': [_Uuid(_docId.toUpperCase())],
            'ownerId': [_bytes(owner)],
            'at': ['2026-10-18T01:02:03.004Z'],
            'kind': [_Kind.y],
            'createdAt': [1700000000123],
          },
        );

      final row = RevPageCodec.decode(pageSchema, b.build()).single.$2;

      expect(row, {
        'id': id,
        'docId': _docId,
        'ownerId': owner,
        'at': DateTime.utc(2026, 10, 18, 1, 2, 3, 4),
        'kind': 'y',
        'createdAt': DateTime.fromMillisecondsSinceEpoch(
          1700000000123,
          isUtc: true,
        ),
      });
    });

    test('when a column has fewer values than ids then encoding fails', () {
      final b = RevPageBuilder(pageSchema);

      expect(
        () => b.addTable('item', [_docId], {'label': <Object?>[]}),
        throwsA(isA<RevCodecException>()),
      );
    });
  });

  group('Given repeating UUIDs and strings', () {
    test('when encoded then dictionaries make the page smaller than unique '
        'values', () {
      final r = Random(4);
      final repeating = randomItems(r, 2000, nullRate: 0, repeatRate: 1);
      final unique = randomItems(r, 2000, nullRate: 0, repeatRate: 0);

      final a = RevPageCodec.encode(pageSchema, repeating, compress: false);
      final b = RevPageCodec.encode(pageSchema, unique, compress: false);

      expect(a.length, lessThan(b.length * 3 ~/ 4));
      expect(
        flat(RevPageCodec.decode(pageSchema, a)),
        flat(decodedForm(pageSchema, repeating)),
      );
    });
  });

  group('Given a page from a newer compatible schema', () {
    final newer = RevSchema('page-test', [
      RevTable(
        'item',
        [
          ...pageSchema.table('item').columns,
          const RevColumn('future', RevColumnType.string, nullable: true),
        ],
        parents: const [RevParent('docId', 'doc')],
        rank: 1,
      ),
      const RevTable('extra', [RevColumn('x', RevColumnType.int)]),
      ...pageSchema.tables.where((t) => t.name != 'item'),
    ]);

    test('when decoded with the older schema then unknown tables and '
        'columns are skipped', () {
      final rows = randomItems(Random(5), 20, docId: _docId);
      final body = RevPageCodec.encode(newer, [
        for (final (t, r) in rows) (t, {...r, 'future': 'f'}),
        ('extra', {'id': _docId, 'x': 1}),
      ]);

      final back = RevPageCodec.decode(pageSchema, body);

      expect(flat(back), flat(decodedForm(pageSchema, rows)));
    });
  });

  group('Given bodies the codec does not read', () {
    final body = RevPageCodec.encode(
      pageSchema,
      randomItems(Random(6), 40, docId: _docId),
    );

    test('when the version is newer then decoding fails and names the '
        'versions it reads', () {
      final future = Uint8List.fromList(body)..[3] = 3;

      expect(
        () => RevPageCodec.decode(pageSchema, future),
        throwsA(
          isA<RevCodecException>().having(
            (e) => e.message,
            'message',
            contains('unsupported page version 3'),
          ),
        ),
      );
    });

    test('when the body is truncated then decoding fails cleanly', () {
      final cut = Uint8List.sublistView(body, 0, body.length ~/ 2);

      expect(
        () => RevPageCodec.decode(pageSchema, cut),
        throwsA(isA<RevCodecException>()),
      );
    });

    test('when the body is not a page then its version is unknown', () {
      expect(
        () => RevPageCodec.versionOf(utf8.encode('{"t":[]}')),
        throwsA(isA<RevCodecException>()),
      );
    });

    test('when a known column has another type then decoding fails', () {
      final other = RevSchema('page-test', [
        const RevTable('doc', [RevColumn('title', RevColumnType.int)]),
      ]);
      final doc = RevPageCodec.encode(other, [
        ('doc', {'id': _docId, 'title': 5}),
      ]);

      expect(
        () => RevPageCodec.decode(pageSchema, doc),
        throwsA(isA<RevCodecException>()),
      );
    });
  });

  test('Given format negotiation when a client asks for no version, the '
      'current one or a newer one then the server serves 1, 2 and 2', () {
    expect(
      [
        RevPageCodec.negotiate(null),
        RevPageCodec.negotiate(2),
        RevPageCodec.negotiate(3),
      ],
      [1, 2, 2],
    );
  });
}

Uint8List _bytes(String uuid) {
  final hex = uuid.replaceAll('-', '');
  return Uint8List.fromList([
    for (var i = 0; i < 16; i++)
      int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
  ]);
}

/// A `UuidValue`-like object (its `toString()` is the UUID).
final class _Uuid {
  const _Uuid(this.value);
  final String value;
  @override
  String toString() => value;
}

enum _Kind { y }
