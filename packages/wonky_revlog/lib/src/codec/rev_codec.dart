import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart' show GZipDecoder, GZipEncoder;

import '../rows/row_change.dart';
import '../schema/rev_schema.dart';
import 'base62.dart';

/// Thrown when a payload can't be decoded or violates the schema.
final class RevCodecException implements Exception {
  /// Creates the exception.
  RevCodecException(this.message);

  /// What is wrong.
  final String message;

  @override
  String toString() => 'RevCodecException: $message';
}

/// Decoded payload: changes plus the summary/detail objects.
typedef RevPayload = ({
  String schemaHash,
  List<RowChange> changes,
  Map<String, Object?>? summary,
  Map<String, Object?>? detail,
});

/// Value conversion between in-memory column maps and the wire (RevLog spec
/// 03 §3.2).
abstract final class RevValues {
  /// Wire value of [v] for [column]. [memo] caches UUID conversions within
  /// one payload (sheet, row and column ids repeat).
  static Object? toWire(
    RevColumn column,
    Object? v, [
    Map<String, String>? memo,
  ]) {
    if (v == null) return null;
    return switch (column.type) {
      RevColumnType.uuid =>
        memo == null
            ? Base62Uuid.encode(v.toString())
            : memo[v.toString()] ??= Base62Uuid.encode(v.toString()),
      RevColumnType.dateTime => _dateMs(v),
      RevColumnType.double => (v as num).toDouble(),
      RevColumnType.int => (v as num).toInt(),
      RevColumnType.enumName => v is Enum ? v.name : v.toString(),
      RevColumnType.bool => v as bool,
      RevColumnType.string || RevColumnType.json => v.toString(),
    };
  }

  /// In-memory value of wire value [v] for [column] (UUIDs as canonical
  /// lower-case strings, DateTimes in UTC, doubles as double); [memo] as
  /// for [toWire].
  static Object? fromWire(
    RevColumn column,
    Object? v, [
    Map<String, String>? memo,
  ]) {
    if (v == null) return null;
    return switch (column.type) {
      RevColumnType.uuid =>
        memo == null
            ? Base62Uuid.decode(v as String)
            : memo[v as String] ??= Base62Uuid.decode(v),
      RevColumnType.dateTime => DateTime.fromMillisecondsSinceEpoch(
        (v as num).toInt(),
        isUtc: true,
      ),
      RevColumnType.double => (v as num).toDouble(),
      RevColumnType.int => (v as num).toInt(),
      RevColumnType.bool => v as bool,
      RevColumnType.enumName ||
      RevColumnType.string ||
      RevColumnType.json => v as String,
    };
  }

  /// In-memory normalization (what [fromWire] of [toWire] returns).
  static Object? normalize(RevColumn column, Object? v) =>
      fromWire(column, toWire(column, v));

  static int _dateMs(Object v) => switch (v) {
    DateTime() => v.toUtc().millisecondsSinceEpoch,
    String() => DateTime.parse(v).toUtc().millisecondsSinceEpoch,
    num() => v.toInt(),
    _ => throw RevCodecException('not a date: $v'),
  };
}

/// Compact JSON codec of change sets and page bodies (RevLog spec 03 §3).
final class RevCodec {
  /// Creates a codec for [schema]. With [lenient], unknown tables and columns
  /// (a compatible newer schema, 02 §4.3) are skipped instead of rejected.
  RevCodec(this.schema, {this.lenient = false});

  /// The schema.
  final RevSchema schema;

  /// Skip unknown tables/columns when decoding.
  final bool lenient;

  /// Codec version.
  static const version = 1;

  static const _absent = {'_': 0};

  /// Encodes [changes] (+ optional summary/detail) as the codec JSON object.
  /// With [withBefore] false, update/delete `before` values are omitted
  /// (the applied form sent to clients, 03 §4.7).
  Map<String, Object?> encode(
    List<RowChange> changes, {
    Map<String, Object?>? summary,
    Map<String, Object?>? detail,
    bool withBefore = true,
  }) {
    // Pass 1: table and column dictionaries.
    final tables = <String>[];
    final tableIdx = <String, int>{};
    final cols = <List<String>>[];
    final colIdx = <String, Map<String, int>>{};
    void register(RowChange ch, Map<String, Object?> m) {
      final table = schema.table(ch.table);
      final ti = tableIdx.putIfAbsent(ch.table, () {
        tables.add(ch.table);
        cols.add([]);
        colIdx[ch.table] = {};
        return tables.length - 1;
      });
      final byName = colIdx[ch.table]!;
      for (final name in m.keys) {
        if (name == RowChange.idColumn || byName.containsKey(name)) continue;
        if (table.column(name) == null) {
          throw RevCodecException('unknown column ${ch.table}.$name');
        }
        byName[name] = cols[ti].length;
        cols[ti].add(name);
      }
    }

    bool keepBefore(RowChange ch) => withBefore && ch.op != RowOp.insert;
    for (final ch in changes) {
      register(ch, ch.columnsAfter);
      if (keepBefore(ch)) register(ch, ch.columnsBefore);
    }

    // Pass 2: rows as arrays aligned with the column dictionary.
    final memo = <String, String>{};
    List<Object?> aligned(RowChange ch, Map<String, Object?> m) {
      final table = schema.table(ch.table);
      final names = cols[tableIdx[ch.table]!];
      return [
        for (final name in names)
          m.containsKey(name)
              ? RevValues.toWire(table.column(name)!, m[name], memo)
              : _absent,
      ];
    }

    final ch = <List<Object?>>[
      for (final c in changes)
        [
          c.op.index,
          tableIdx[c.table],
          Base62Uuid.encode(c.rowId),
          if (c.op != RowOp.delete) aligned(c, c.columnsAfter) else null,
          if (keepBefore(c)) aligned(c, c.columnsBefore),
        ],
    ];
    return {
      'v': version,
      's': schema.hash,
      't': tables,
      'c': cols,
      'ch': ch,
      'sum': ?summary,
      'det': ?detail,
    };
  }

  /// Decodes a codec JSON object.
  RevPayload decode(Map<String, Object?> json) {
    if (json['v'] != version) {
      throw RevCodecException('unsupported codec version ${json['v']}');
    }
    final tables = (json['t']! as List).cast<String>();
    final cols = [
      for (final c in json['c']! as List) (c as List).cast<String>(),
    ];
    final changes = <RowChange>[];
    final memo = <String, String>{};
    for (final raw in json['ch']! as List) {
      final row = raw as List;
      final op = RowOp.values[(row[0]! as num).toInt()];
      final tName = tables[(row[1]! as num).toInt()];
      final table = schema.tryTable(tName);
      if (table == null) {
        if (lenient) continue;
        throw RevCodecException('unknown table $tName');
      }
      final id = Base62Uuid.decode(row[2]! as String);
      final names = cols[(row[1]! as num).toInt()];
      Map<String, Object?> readMap(Object? values) {
        if (values is! List) return {};
        final m = <String, Object?>{};
        for (var i = 0; i < values.length && i < names.length; i++) {
          final v = values[i];
          if (v is Map && v['_'] == 0) continue;
          final col = table.column(names[i]);
          if (col == null) {
            if (lenient) continue;
            throw RevCodecException('unknown column $tName.${names[i]}');
          }
          m[names[i]] = RevValues.fromWire(col, v, memo);
        }
        return m;
      }

      final after = row.length > 3 ? readMap(row[3]) : <String, Object?>{};
      final before = row.length > 4 ? readMap(row[4]) : <String, Object?>{};
      changes.add(switch (op) {
        RowOp.insert => RowChange.insert(tName, id, after),
        RowOp.update => RowChange.update(tName, id, before, after),
        RowOp.delete =>
          before.isEmpty
              ? RowChange(table: tName, rowId: id, op: RowOp.delete)
              : RowChange.delete(tName, id, before),
      });
    }
    return (
      schemaHash: json['s']! as String,
      changes: changes,
      summary: (json['sum'] as Map?)?.cast<String, Object?>(),
      detail: (json['det'] as Map?)?.cast<String, Object?>(),
    );
  }

  /// UTF-8 JSON text of [encode].
  String encodeText(
    List<RowChange> changes, {
    Map<String, Object?>? summary,
    Map<String, Object?>? detail,
    bool withBefore = true,
  }) => jsonEncode(
    encode(changes, summary: summary, detail: detail, withBefore: withBefore),
  );

  /// Decodes JSON text.
  RevPayload decodeText(String text) =>
      decode((jsonDecode(text) as Map).cast<String, Object?>());

  /// Gzip of UTF-8 [text].
  static Uint8List gzip(String text) =>
      Uint8List.fromList(const GZipEncoder().encodeBytes(utf8.encode(text)));

  /// Text of gzip [bytes].
  static String gunzip(List<int> bytes) =>
      utf8.decode(const GZipDecoder().decodeBytes(bytes));

  /// Payload text, or null when it should travel compressed (> [threshold]).
  static ({String? text, Uint8List? gz}) pack(
    String text, {
    int threshold = 16384,
  }) {
    if (text.length <= threshold) return (text: text, gz: null);
    return (text: null, gz: gzip(text));
  }

  /// Text from a packed payload.
  static String unpack({String? text, List<int>? gz}) {
    if (text != null) return text;
    if (gz != null) return gunzip(gz);
    throw RevCodecException('empty payload');
  }
}
