import 'dart:math';

import 'package:wonky_revlog/codec.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_revlog/schema.dart';

/// A schema with every column type, nullable and non-null columns, and
/// columns with non-null defaults (page codec tests).
final pageSchema = RevSchema('page-test', const [
  RevTable('doc', [
    RevColumn('title', RevColumnType.string),
    RevColumn('mode', RevColumnType.enumName, enumValues: ['a', 'b']),
    RevColumn('zoom', RevColumnType.double, nullable: true, defaultValue: 1.0),
    RevColumn('flag', RevColumnType.bool, nullable: true, defaultValue: false),
  ], isRoot: true),
  RevTable(
    'item',
    [
      RevColumn('docId', RevColumnType.uuid, immutable: true),
      RevColumn('ownerId', RevColumnType.uuid, nullable: true),
      RevColumn('label', RevColumnType.string, nullable: true),
      RevColumn('count', RevColumnType.int, nullable: true),
      RevColumn('size', RevColumnType.double, nullable: true),
      RevColumn('on', RevColumnType.bool, nullable: true),
      RevColumn('at', RevColumnType.dateTime, nullable: true),
      RevColumn('kind', RevColumnType.enumName, nullable: true),
      RevColumn('data', RevColumnType.json, nullable: true),
      RevColumn('createdAt', RevColumnType.dateTime),
    ],
    parents: [RevParent('docId', 'doc')],
    rank: 1,
  ),
]);

/// A deterministic UUID string from [r].
String randomUuid(Random r) {
  const hex = '0123456789abcdef';
  final b = StringBuffer();
  for (var i = 0; i < 32; i++) {
    if (i == 8 || i == 12 || i == 16 || i == 20) b.write('-');
    b.write(hex[r.nextInt(16)]);
  }
  return b.toString();
}

/// [n] random `item` rows: each nullable column is null with probability
/// [nullRate]; strings and UUIDs repeat with probability [repeatRate]
/// (dictionary blocks).
List<(String, Map<String, Object?>)> randomItems(
  Random r,
  int n, {
  double nullRate = 0.5,
  double repeatRate = 0.5,
  String? docId,
}) {
  final doc = docId ?? randomUuid(r);
  final owners = [for (var i = 0; i < 4; i++) randomUuid(r)];
  final words = [
    '',
    'a',
    'ünïcødé ⟦R:x⟧',
    'emoji 🙂',
    'line\nbreak',
    'x' * 300,
  ];
  Object? maybe(Object? Function() f) => r.nextDouble() < nullRate ? null : f();
  String text() => r.nextDouble() < repeatRate
      ? words[r.nextInt(words.length)]
      : 'v${r.nextInt(1 << 30)}';
  return [
    for (var i = 0; i < n; i++)
      (
        'item',
        <String, Object?>{
          RowChange.idColumn: randomUuid(r),
          'docId': doc,
          'ownerId': maybe(
            () => r.nextDouble() < repeatRate
                ? owners[r.nextInt(owners.length)]
                : randomUuid(r),
          ),
          'label': maybe(text),
          'count': maybe(
            () => switch (r.nextInt(4)) {
              0 => 0,
              1 => -r.nextInt(1 << 31),
              2 => r.nextInt(1 << 31) * 1000,
              _ => r.nextInt(300),
            },
          ),
          'size': maybe(
            () => switch (r.nextInt(3)) {
              0 => r.nextDouble() * 1e6 - 5e5,
              1 => r.nextInt(100).toDouble(),
              _ => -0.0,
            },
          ),
          'on': maybe(r.nextBool),
          'at': maybe(
            () => DateTime.fromMillisecondsSinceEpoch(
              1700000000000 + r.nextInt(1 << 30) - (1 << 29),
              isUtc: true,
            ),
          ),
          'kind': maybe(() => ['x', 'y', 'z'][r.nextInt(3)]),
          'data': maybe(() => '{"k":${r.nextInt(9)}}'),
          'createdAt': DateTime.fromMillisecondsSinceEpoch(
            1700000000000 + i * 7,
            isUtc: true,
          ),
        },
      ),
  ];
}

/// What [RevPageCodec.decode] returns for [rows]: in-memory values, null
/// columns left out unless the column has a non-null default.
List<(String, Map<String, Object?>)> decodedForm(
  RevSchema schema,
  List<(String, Map<String, Object?>)> rows,
) => [
  for (final (t, row) in rows)
    (
      t,
      {
        RowChange.idColumn: row[RowChange.idColumn].toString().toLowerCase(),
        for (final c in schema.table(t).columns)
          if (row[c.name] case final v?)
            c.name: RevValues.normalize(c, v)
          else if (c.defaultValue != null)
            c.name: null,
      },
    ),
];

/// Flat comparable form of rows (records compare by identity of maps).
List<Object> flat(List<(String, Map<String, Object?>)> rows) => [
  for (final (t, r) in rows) [t, r],
];
